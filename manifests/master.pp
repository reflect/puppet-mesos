# Class: mesos::master
#
# This module manages Mesos master - installs Mesos package
# and starts master service.
#
# Sample Usage:
#
# class{ 'mesos::master': }
#
# Parameters:
#
#  [*single_role*]
#    Currently Mesos packages ships with both mesos-master and mesos-slave
#    enabled by default. `single_role` assumes that you use only either of
#    those on one machine. Default: true (mesos-slave service will be
#    disabled on master node)
#
#
# mesos-master service stores configuration in /etc/default/mesos-master in file/directory
# structure. Arguments passed via $options hash are converted to file/directories
#
class mesos::master(
  $acls             = {},
  $acls_file        = '/etc/mesos/acls',
  $cluster          = 'mesos',
  $conf_dir         = '/etc/mesos-master',
  $conf_file        = $mesos::conf_file,
  $conf_file        = '/etc/default/mesos-master',
  $credentials      = [],
  $credentials_file = '/etc/mesos/master-credentials',
  $enable           = true,
  $ensure           = $mesos::ensure,
  $env_var          = $mesos::env_var,
  $force_provider   = undef, #temporary workaround for starting services
  $group            = $mesos::group,
  $listen_address   = $mesos::listen_address,
  $log_dir          = $mesos::log_dir,
  $manage_python    = $mesos::manage_python,
  $manage_service   = $mesos::manage_service,
  $manage_zk_file   = $mesos::manage_zk_file,
  $manage_zookeeper = $mesos::manage_zookeeper,
  $master_port      = $mesos::master_port,
  $options          = {},
  $owner            = $mesos::owner,
  $python_package   = $mesos::python_package,
  $repo             = $mesos::repo,
  $single_role      = $mesos::single_role,
  $syslog_logger    = true,
  $ulimit           = $mesos::ulimit,
  $use_hiera        = $mesos::use_hiera,
  $version          = $mesos::version,
  $work_dir         = '/var/lib/mesos', # registrar directory, since 0.19
  $zk_default_port  = $mesos::zk_default_port,
  $zk_path          = $mesos::zk_path,
  $zookeeper        = $mesos::zookeeper,
) inherits mesos {
  validate_hash($options)
  validate_hash($acls)
  validate_absolute_path($acls_file)
  validate_array($credentials)
  validate_absolute_path($credentials_file)
  validate_bool($manage_service)
  validate_bool($syslog_logger)
  validate_bool($single_role)
  validate_bool($manage_zk_file)

  if (!empty($acls)) {
    $acls_options = {'acls' => $acls_file}
    $acls_content = inline_template("<%= require 'json'; @acls.to_json %>")
    $acls_ensure = file
  } else {
    $acls_options = {}
    $acls_content = undef
    $acls_ensure = absent
  }

  if (!empty($credentials)) {
    $credentials_options = {'credentials' => "file://${credentials_file}"}
    $credentials_content = inline_template("<%= require 'json'; {:credentials => @credentials}.to_json %>")
    $credentials_ensure = file
  } else {
    $credentials_options = {}
    $credentials_content = undef
    $credentials_ensure = absent
  }

  if $use_hiera {
    # In Puppet 3 automatic lookup won't merge options across multiple config
    # files, see https://www.devco.net/archives/2016/02/03/puppet-4-data-lookup-strategies.php
    $opts = hiera_hash('mesos::master::options', $options)
    $merged_options = merge($opts, $acls_options, $credentials_options)
  } else {
    $merged_options = merge($options, $acls_options, $credentials_options)
  }

  mesos::node { 'master':
    ensure           => $ensure,
    version          => $version,
    repo             => $repo,
    manage_python    => $mesos::manage_python,
    manage_zookeeper => $manage_zookeeper,
    manage_zk_file   => $manage_zk_file,
    zookeeper        => $zookeeper,
    env_var          => $env_var,
  }

  file { $conf_dir:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    recurse => true,
    purge   => true,
    force   => true,
    require => Class['::mesos::install'],
    notify  => Service['mesos-master'], # when key is removed we want to reload the service
  }

  file { $work_dir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { $acls_file:
    ensure  => $acls_ensure,
    content => $acls_content,
    owner   => $owner,
    group   => $group,
    mode    => '0444',
  }

  file { $credentials_file:
    ensure  => $credentials_ensure,
    content => $credentials_content,
    owner   => $owner,
    group   => $group,
    mode    => '0400',
  }

  # work_dir can't be specified via options,
  # we would get a duplicate declaration error
  mesos::property {'master_work_dir':
    value  => $work_dir,
    dir    => $conf_dir,
    file   => 'work_dir',
    owner  => $owner,
    group  => $group,
    notify => Service['mesos-master'],
  }

  create_resources(mesos::property,
    mesos_hash_parser($merged_options, 'master'),
    {
      dir    => $conf_dir,
      owner  => $owner,
      group  => $group,
      notify => Service['mesos-master'],
    }
  )

  # TODO: This is kind of copy-pasta'd all over the place. How can we refactor
  # this to make it more sane?
  if !empty($zookeeper) {
    if is_string($zookeeper) {
      warning('\$zookeeper parameter should be an array of IP addresses, please update your configuration.')
    }
    $zookeeper_url = zookeeper_servers_url($zookeeper, $zk_path, $zk_default_port)
  }

  file { $conf_file:
    ensure  => present,
    content => template('mesos/master.erb'),
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    require => [File[$conf_dir], Package['mesos']],
  }

  # When launched by the "mesos-init-wrapper", the Mesos service's stdout/stderr
  # are logged to syslog using logger (http://linux.die.net/man/1/logger). This
  # is disabled using the "--no-logger" flag. There is no equivalent "--logger"
  # flag so the option must either be present or completely removed.
  $logger_ensure = $syslog_logger ? {
    true  => absent,
    false => present,
  }

  mesos::property { 'master_logger':
    ensure => $logger_ensure,
    file   => 'logger',
    value  => false,
    dir    => $conf_dir,
    owner  => $owner,
    group  => $group,
  }

  # Install mesos-master service
  mesos::service { 'master':
    enable         => $enable,
    force_provider => $force_provider,
    manage         => $manage_service,
    subscribe      => File[$conf_file],
  }

  if (!defined(Class['mesos::slave']) and $single_role) {
    mesos::service { 'slave':
      enable => false,
      manage => $manage_service,
    }
  }
}
