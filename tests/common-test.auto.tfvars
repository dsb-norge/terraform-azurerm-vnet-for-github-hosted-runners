# default inputs for unit tests

github_database_id = "12345678"
network_specs = {
  address_space         = "10.0.0.0/25"
  additional_pe_subnets = ["10.0.1.0/25"]
  tags = {
    IPAMReservation = "IpamReservationID"
  }
}
location          = "norwayeast"
system_name       = "test-github-integration"
system_short_name = "test-gh"
tags = {
  Environment = "test"
  Project     = "GitHub Runner VNet Unit Tests"
}
