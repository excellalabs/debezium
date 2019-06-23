desc 'Deploy Debezium Connect ELB'
task :'deploy:elb' do
  puts 'deploy elb cloudformation template'
  stack_name = 'DEBEZIUM-ELB'

  public_subnets = get_subnets('public')
  public_sg = @keystore.retrieve('PUBLIC_SECURITY_GROUP')

  parameters = {
    'VpcId' => @keystore.retrieve('VPC_ID'),
    'SubnetIds' => public_subnets,
    'SecurityGroupId' => public_sg,
    'Port' => @port,
    'SslCertArn' => @keystore.retrieve('SSL_CERT_ARN')
  }

  @cloudformation.deploy_stack(
    stack_name,
    parameters,
    'provisioning/elb.yml'
  )
  puts 'done!'
end

desc 'Deploy Debezium Connect ECS'
task :'deploy:ecs' do
  puts 'deploy ecs cloudformation template'
  stack_name = 'XSP-DEBEZIUM-ECS'
  service_name = 'debezium-connect'
  private_subnets = get_subnets('private')
  private_sg = @keystore.retrieve('PRIVATE_SECURITY_GROUP')
  # target_group = \
  #   @cloudformation.stack_output('DEBEZIUM-ELB', 'TargetGroup')
  kafka_url = @keystore.retrieve('KAFKA_BOOTSTRAP_SERVERS')
  ecs_cluster = @keystore.retrieve('INTERNAL_ECS_CLUSTER')

  parameters = {
    'Cluster' => ecs_cluster,
    'ServiceName' => service_name,
    'VPC' => @keystore.retrieve('VPC_ID'),
    'PrivateSubnetIds' => private_subnets,
    'EcsSecurityGroup' => private_sg,
    # 'TargetGroup' => target_group,
    'Image' => @docker_image,
    'Port' => @port,
    'KafkaUrl' => kafka_url
  }

  @cloudformation.deploy_stack(
    stack_name,
    parameters,
    'provisioning/fargate.yml',
    ['CAPABILITY_NAMED_IAM']
  )
  puts 'done!'
end
