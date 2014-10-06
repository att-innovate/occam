# hosts.rake (in /lib/tasks)
namespace :domains do

  desc "adds the necessary hosts (fqdn) to your /etc/hosts "
  task :setup do
    # NOTE: default_hosts is used as a locator for the line to update in /etc/hosts
    tmp_file, changed = '/tmp/etc_hosts_copy', false
    default_hosts, hosts    = %w(cloud.zone1.example.com), []

    # build hosts line to add/edit
    host_line = "192.168.4.11 " + hosts.sort.unshift(default_hosts).join(' ')

    # work with a copied hosts file in tmp
    %x[cp /etc/hosts #{tmp_file}]

    file = File.new(tmp_file)
    lines = file.readlines
    lines.each do |line|
      changed = true if line.gsub!(/^192.168.4.11 #{Regexp.escape(default_hosts.join(' '))}.+$/, host_line)
    end

    # add line, if no line found for update
    lines += ["\n", host_line, "\n"] unless changed
    file = File.new(tmp_file,'w')
    lines.each { |line| file.write(line) }
    file.close

    # copy hosts file from tmp - may ask for sudo password
    %x[sudo -p "Password:" cp #{tmp_file} /etc/hosts]
    
    # explain what happened
    puts "\nAdded the following domains:"
    hosts.each { |host| puts "* https://#{host}" }
    puts "\nAlso added defaults:"
    default_hosts.each { |default| puts "* https://#{default}" }
    puts "\n"
  end
end
