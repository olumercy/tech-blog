/*variable "access_key" {
    type=string
    sensitive = true
}


variable "secret_key" {
    type = string
    sensitive = true
}


variable "token" {
    type=string
    sensitive = true


}
*/

variable "region" {
    default = "eu-west-1"
    sensitive = false
}