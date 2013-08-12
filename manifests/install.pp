class solr::install ($source_url, $home_dir, $solr_data_dir, $package, $cores) {
  $tmp_dir = "/var/tmp"
  $solr_dist_dir = "${home_dir}/dist"
  $solr_package = "${solr_dist_dir}/${package}.war"
  $solr_home_dir = "${home_dir}"
  $destination = "$tmp_dir/$package.tgz"

  user {solr:
    ensure => present,
    gid => "solr",
  }
  group {solr:
    ensure => present
  }

  package {"java-1.7.0-openjdk":
    ensure => present,
  }

  exec { "solr_home_dir":
    command => "echo 'ceating ${solr_home_dir}' && mkdir -p ${solr_home_dir}",
    path => ["/bin", "/usr/bin", "/usr/sbin"],
    creates => $solr_home_dir
  }

  exec { "download-solr":
    command => "wget $source_url",
    creates => "$destination",
    cwd => "$tmp_dir",
    path => ["/bin", "/usr/bin", "/usr/sbin"],
    require => Exec["solr_home_dir"],
  }

  exec { "unpack-solr":
    command => "tar -xzf $destination --directory=$tmp_dir",
    creates => "$tmp_dir/$package",
    cwd => "$tmp_dir",
    require => Exec["download-solr"],
    path => ["/bin", "/usr/bin", "/usr/sbin"],
  }

  # Ensure solr dist directory exist, with the appropriate privileges and copy contents of tar'd dist directory
  file { $solr_dist_dir:
    ensure => directory,
    require => Exec["unpack-solr"],
    source => "${tmp_dir}/${package}/dist/",
    recurse => true,
    group   => "solr",
    owner   => "solr",
  }

  # Ensure solr home directory exist, with the appropriate privileges and copy contents of example package to set this up
  file { $solr_home_dir:
    ensure => directory,
    require => Exec["unpack-solr"],
    source => "${tmp_dir}/$package/example/solr",
    recurse => true,
    group   => "solr",
    owner   => "solr",
  }

  # Create cores
  solr::core {$cores:
    base_data_dir => $solr_data_dir,
    solr_home => $home_dir,
  }

  # Create Solr file referencing new cores
  file { "$solr_home_dir/solr.xml":
    ensure => present,
    content => template("solr/solr.xml.erb"),
    group   => "solr",
    owner   => "solr",
  }
}
