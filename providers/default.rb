use_inline_resources

def whyrun_supported?
  true
end

# Windows 2.x has bin directory but 1.x does not
def win_bin?
  new_resource.version.split('.')[0].to_i > 1
end

def executable
  "#{new_resource.path}/#{new_resource.basename}/bin/phantomjs"
end

def version_installed?
  cmd = Mixlib::ShellOut.new("#{executable} -v")
  cmd.run_command
  cmd.error!
  cmd.stdout.chomp == new_resource.version
end

action :install do

  directory new_resource.path do
    recursive true
    mode '0755'
    owner new_resource.user
    group new_resource.group
  end

  new_resource.packages.each { |name| package name }

  extension = 'tar.bz2'
  download_path = "#{new_resource.path}/#{new_resource.basename}.#{extension}"

  remote_file download_path do
    owner new_resource.user
    group new_resource.group
    mode '0644'
    backup false
    retries 300 # bitbucket can throw a lot of 403 Forbidden errors before finally downloading
    source "#{new_resource.base_url}/#{new_resource.basename}.#{extension}"
    checksum new_resource.checksum if new_resource.checksum
    not_if { ::File.exist?(executable) && version_installed? }
    notifies :run, "execute[untar #{new_resource.basename}.tar.bz2]", :immediately
  end


  execute "untar #{new_resource.basename}.tar.bz2" do
    command "tar -xvjf #{new_resource.path}/#{new_resource.basename}.tar.bz2"
    cwd new_resource.path
    action :nothing
  end

  link "phantomjs-link #{executable}" do
    target_file '/usr/local/bin/phantomjs'
    to executable
    owner new_resource.user
    group new_resource.group
    action :create
    only_if { new_resource.link }
  end

end
