variable "naming" {
     type = object({
         resource_prefix = string
          tags = map(string)
           })
         }