@cloudformation = MinimalPipeline::Cloudformation.new
@keystore = MinimalPipeline::Keystore.new
@docker = MinimalPipeline::Docker.new

@region = 'us-east-1'
ENV['region'] = @region

docker_repo = @keystore.retrieve('ECR_REPOSITORY')
@ecr_repo_name = 'xsp-debezium'
@docker_image = "#{docker_repo}/#{@ecr_repo_name}:latest"
@service_name = 'debezium-connect'
@port = '8083'

def get_subnets(subnet_cluster)
  subnet_cluster.upcase!
  subnet1 = @keystore.retrieve("#{subnet_cluster}_SUBNET_1")
  subnet2 = @keystore.retrieve("#{subnet_cluster}_SUBNET_2")
  subnet3 = @keystore.retrieve("#{subnet_cluster}_SUBNET_3")
  [subnet1, subnet2, subnet3].join(',')
end
