{
  "network" => {
    "dhcp" => false,
    "hosts" => {
      "management" => {
        "pools" => [{
          "minIp" => "192.168.10.1",
          "maxIp" => "192.168.10.4"
        }],
        "netmask" => "255.255.255.0",
        "gateway" => "192.168.10.254"
      },
      "vsan" => {
        "pools" => [{
          "minIp" => "192.168.30.1",
          "maxIp" => "192.168.30.4"
        }],
        "netmask" => "255.255.255.0",
        "vlanId" => 30
      },
      "vm" => [{
        "name" => "VM Network A",
        "vlanId" => 110
      }, {
        "name" => "VM Network B",
        "vlanId" => 120
      }],
      "vmotion" => {
        "pools" => [{
          "minIp" => "192.168.20.1",
          "maxIp" => "192.168.20.4"
        }],
        "netmask" => "255.255.255.0",
        "vlanId" => 20
      }
    },
    "vcenter" => {
      "ip" => "192.168.10.200"
    }
  },
  "hostnames" => {
    "hosts" => {
      "prefix" => "host",
      "separator" => "",
      "iterator" => "NUMERIC_NN"
    },
    "tld" => "localdomain.local",
    "vcenter" => "vcserver"
  },
  "passwords" => {
    "esxiPassword" => "",
    "esxiPasswordConfirm" => "",
    "vcPassword" => "",
    "vcPasswordConfirm" => "",
    "activeDirectoryDomain" => "",
    "activeDirectoryUsername" => "",
    "activeDirectoryPassword" => "",
    "activeDirectoryPasswordConfirm" => ""
  },
  "global" => {
    "logging" => "LOGINSIGHT",
    "timezone" => "UTC",
    "loginsightServer" => "192.168.10.201",
    "loginsightHostname" => "loginsight",
    "ntpServerCSV" => "",
    "syslogServerCSV" => "",
    "dnsServerCSV" => "",
    "proxyServer" => "",
    "proxyPort" => "",
    "proxyUsername" => "",
    "proxyPassword" => ""
  }
}
