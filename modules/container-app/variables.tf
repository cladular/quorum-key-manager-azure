variable "name" {

}

variable "location" {

}

variable "resource_group_id" {

}

variable "resource_group_name" {

}

variable "subnet_id" {

}

variable "storage_account_name" {

}

variable "storage_account_key" {
  sensitive = true
}

variable "share_name" {

}

variable "db_host" {

}

variable "db_database" {

}

variable "db_user" {
  sensitive = true
}

variable "db_password" {
  sensitive = true
}
