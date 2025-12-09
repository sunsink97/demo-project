#!/bin/bash
set -xe

LOG_FILE="/var/log/user-data.log"

log() {
  echo "$1" >> "$LOG_FILE"
}

log "step 1 start - system update and install nginx + agents"

dnf update -y >> "$LOG_FILE" 2>&1
dnf install -y nginx amazon-cloudwatch-agent amazon-ssm-agent ruby wget >> "$LOG_FILE" 2>&1

systemctl enable nginx >> "$LOG_FILE" 2>&1
systemctl start nginx >> "$LOG_FILE" 2>&1

systemctl enable amazon-ssm-agent >> "$LOG_FILE" 2>&1
systemctl start amazon-ssm-agent >> "$LOG_FILE" 2>&1

log "step 1 end"
log "step 2 start - install codedeploy agent"

cd /tmp
wget https://aws-codedeploy-ap-southeast-1.s3.amazonaws.com/latest/install >> "$LOG_FILE" 2>&1
chmod +x ./install
./install auto >> "$LOG_FILE" 2>&1

systemctl enable codedeploy-agent >> "$LOG_FILE" 2>&1
systemctl start codedeploy-agent >> "$LOG_FILE" 2>&1

log "step 2 end"
log "step 3 start - configure cloudwatch agent"

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat << 'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
      "InstanceId": "$${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"],
        "metrics_collection_interval": 60
      },
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": true
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/ec2/system/messages",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/ec2/nginx/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/ec2/nginx/error",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/ec2/userdata",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s >> "$LOG_FILE" 2>&1

log "step 3 end"
log "user data complete"
