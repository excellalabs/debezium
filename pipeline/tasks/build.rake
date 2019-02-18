desc 'Build debezium connector image'
task :'build:image' do
  puts 'build docker image for kafka consumer'

  # authentication
  system('$(aws ecr get-login --no-include-email --region us-east-1)')

  @docker.build_docker_image(@docker_image, 'container')
  @docker.push_docker_image(@docker_image)

  puts 'done!'
end
