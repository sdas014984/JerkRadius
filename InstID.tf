/*
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "one" {
  count                  = 4
  ami                    = "ami-0360c520857e3138f"
  instance_type          = "t2.medium"
  key_name               = "suv-key-pair"
  vpc_security_group_ids = ["vpc-008bfd2d364bc93b3"]
  tags = {
    Name = var.instance_names[count.index]
  }
}

variable "instance_names" {
  default = ["jenkins", "APPSERVER-1", "APPSERVER-2", "Monitoring server"]
}
*/
/*
resource "aws_instance" "multiple_instances" {
  count                  = 3
  ami                    = "ami-0360c520857e3138f"
  instance_type          = "t2.medium"
  key_name               = "suv-key-pair"
  vpc_security_group_ids = ["sg-03d6fe3e4c0a53fa8"]
  user_data              = <<-EOF
              #!/bin/bash
              echo "Instance ${count.index} started!" > /tmp/startup.log
              EOF
  tags = {
    Name = "MyInstance-${count.index}"
  }
}
*/
/*
data "template_file" "startup_script" {
  template = file("${path.module}/startup.sh.tpl")
  vars = {
    hostname = "MyInstance"
  }
}

resource "aws_instance" "example_instance" {
  ami                    = "ami-0360c520857e3138f"
  instance_type          = "t2.medium"
  key_name               = "suv-key-pair"
  vpc_security_group_ids = ["sg-03d6fe3e4c0a53fa8"]
  user_data              = data.template_file.startup_script.rendered
  tags = {
    Name = "MyExampleInstance"

  }
}
*/
/*
locals {
  jenkins_script = templatefile("${path.module}/jenkins.sh.tpl", {
    hostname = "jenkins"
  })
}
locals {
  tomcat_script = templatefile("${path.module}/tomcat.sh.tpl", {
    hostname = "tomcat"
  })
}
locals {
  grafana_script = templatefile("${path.module}/grafana.sh.tpl", {
    hostname = "monitoring-server"
  })
}


locals {
  instance_names = ["jenkins", "appserver-1", "appserver-2", "monitoring-server"]
}

resource "aws_instance" "named_instances" {
  for_each               = toset(local.instance_names)
  ami                    = "ami-0360c520857e3138f"
  instance_type          = "t3.micro"
  key_name               = "suv-key-pair"
  vpc_security_group_ids = ["sg-03d6fe3e4c0a53fa8"]
  user_data              = 
    #!/bin/bash
    if [ "${each.value}" = "jenkins" ]; then
      return local.jenkins_script
    fi

    if [ ${each.value} = "appserver-1" || ${each.value} = "appserver-2" ]; then
        return local.tomcat_script
    fi

    if [ ${each.value} = "grafana" ]; then
      return local.grafana_script
    fi

  tags = {
    Name = ${each.value}
  }
              echo "Instance ${each.value} started!" > /tmp/startup.log
  tags = {
    Name = "${each.value}"
  }

}

locals {
  jenkins_script = file("scripts/jenkins.sh.tpl")
  tomcat_script  = file("scripts/tomcat.sh.tpl")
  grafana_script = file("scripts/grafana.sh.tpl")
}
*/
resource "aws_instance" "server" {
  for_each = toset(["jenkins", "appserver-1", "appserver-2", "grafana"])

  ami                    = "ami-0360c520857e3138f"
  instance_type          = "t3.micro"
  key_name               = "suv-key-pair"
  vpc_security_group_ids = ["sg-03d6fe3e4c0a53fa8"]
  user_data = file(
    each.value == "jenkins" ? "jenkins.sh.tpl" :
    contains(["appserver-1", "appserver-2"], each.value) ? "tomcat.sh.tpl" :
    each.value == "grafana" ? "grafana.sh.tpl" :
    "startup.sh.tpl"
  )
  /*
  user_data = <<-EOF
    #!/bin/bash
    echo "Starting ${each.value} setup..." > /tmp/startup.log

    %{ if each.value == "jenkins" }
      ${local.jenkins_script}
    %{ elseif each.value == "appserver-1" || each.value == "appserver-2" }
      ${local.tomcat_script}
    %{ elseif each.value == "grafana" }
      ${local.grafana_script}
    %{ else }
      echo "Unknown server type: ${each.value}" >> /tmp/startup.log
    %{ endif %}

    echo "Instance ${each.value} started!" >> /tmp/startup.log
  EOF
*/
  tags = {
    Name = each.value
  }
}
