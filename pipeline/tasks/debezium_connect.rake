require 'aws-sdk-ecs'

desc 'Setup debezium connect'
task :'debezium:setup' do
  puts 'setting up debezium connect'

  require 'erb'
  @db_host = @keystore.retrieve('KAFKA_CONSUMER_RDS_HOST')
  @db_port = '5432'
  @db_user = @keystore.retrieve('KAFKA_CONSUMER_RDS_USER')
  @db_password = @keystore.retrieve('KAFKA_CONSUMER_RDS_PASSWORD')
  @db_name = 'postgres'
  @server_name = 'db'
  @schemas = %w[public].join(',')
  config_name = 'debezium-connector.json'
  template = ERB.new File.read('./debezium-connector.json.erb')

  File.write("./#{config_name}", template.result(binding))

  # get the private ip address
  private_ip = get_service_ip_address(@service_name)

  # create debezium connection
  curl_command = "curl -i -X POST \
    -H 'Accept:application/json' \
    -H 'Content-Type:application/json' \
    http://#{private_ip}:8083/connectors/ -d @#{config_name}"

  system curl_command

  puts 'done!'
end

def get_service_ip_address(service_name)
  client = Aws::ECS::Client.new(region: @region)
  cluster_name = @keystore.retrieve('INTERNAL_ECS_CLUSTER')
  # get running task arn
  task_id = get_task_id(client, cluster_name, service_name)
  tasks = client.describe_tasks(
    cluster: cluster_name,
    tasks: [task_id]
  ).tasks

  tasks.first.containers.first.network_interfaces.first.private_ipv_4_address
end

def get_task_id(client, cluster_name, service_name)
  task_arn = client.list_tasks(
    cluster: cluster_name,
    service_name: service_name,
    desired_status: 'RUNNING',
    max_results: 1
  ).task_arns.first

  task_arn.split('/')[1]
end
