desc 'Build debezium connector image'
task :'build:image' do
  puts 'build docker image for kafka consumer'

  @docker.build_docker_image(@docker_image, 'container')
  @docker.push_docker_image(@docker_image)

  puts 'done!'
end
