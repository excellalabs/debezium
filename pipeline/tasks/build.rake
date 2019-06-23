desc 'Build debezium connector image'
task :'build:image' do
  puts 'build docker image for debezium'

  # authentication
  system('$(aws ecr get-login --no-include-email --region us-east-1)')
  # build the ecr repo if not exists
  system("ws ecr describe-repositories --region us-east-1 \
    --repository-names #{@ecr_repo_name} || \
    aws ecr create-repository --region us-east-1 \
    --repository-name #{@ecr_repo_name}")

  @docker.build_docker_image(@docker_image, 'container')
  @docker.push_docker_image(@docker_image)

  puts 'done!'
end
