
// create weekly ec2 patching based on tag using system manager
resource "aws_ssm_maintenance_window" "weekly_patching" {
  name                       = "${var.project_name}-${var.env}-weekly-patching"
  schedule                   = "cron(0 3 ? * MON *)" //senin jam 10 pagi
  duration                   = 2
  cutoff                     = 1
  allow_unassociated_targets = false
}

resource "aws_ssm_maintenance_window_target" "patch_targets" {
  window_id     = aws_ssm_maintenance_window.weekly_patching.id
  name          = "${var.project_name}-${var.env}-patch-targets"
  description   = "Patch instances scheduled for Monday 10:00 WIB"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:MaintenanceWindw"
    values = ["MON_10_WIB"]
  }
}

// run awspatchbaseline
resource "aws_iam_role" "ssm_mw_role" {
  name               = "${var.project_name}-${var.env}-ssm-mw-role"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume.json
}

data "aws_iam_policy_document" "ssm_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm_mw_service_role" {
  role       = aws_iam_role.ssm_mw_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

resource "aws_ssm_maintenance_window_task" "run_patch_baseline" {
  window_id        = aws_ssm_maintenance_window.weekly_patching.id
  name             = "${var.project_name}-${var.env}-runpatchbaseline"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  service_role_arn = aws_iam_role.ssm_mw_role.arn
  priority         = 1
  max_concurrency  = "50%"
  max_errors       = "10%"




  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patch_targets.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      timeout_seconds = 3600
      parameter {
        name   = "Operation"
        values = ["Install"]
      }

      parameter {
        name   = "RebootOption"
        values = ["RebootIfNeeded"]
      }
    }
  }

  
}
