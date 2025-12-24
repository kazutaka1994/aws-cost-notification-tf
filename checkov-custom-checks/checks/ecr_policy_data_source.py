from typing import Any

from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck


class EcrPolicyUsesDataSource(BaseResourceCheck):
    """Check that ECR policies use data.aws_iam_policy_document."""

    def __init__(self) -> None:
        name = (
            "Ensure ECR repository policies are defined "
            "using data source aws_iam_policy_document"
        )
        id = "CKV2_AWS_ECR_POLICY_DATA"
        supported_resources = ["aws_ecr_repository_policy"]
        categories = [CheckCategories.IAM]
        super().__init__(
            name=name,
            id=id,
            categories=categories, supported_resources=supported_resources
        )

    def scan_resource_conf(self, conf: dict[str, Any]) -> CheckResult:
        """
        Verify policy references a data source.

        The policy attribute must reference data.aws_iam_policy_document.<name>.json
        """
        if "policy" not in conf:
            # Policy attribute is required
            return CheckResult.FAILED

        policy = conf["policy"]

        # Handle list format (Terraform sometimes wraps values in lists)
        if isinstance(policy, list):
            if len(policy) == 0:
                return CheckResult.FAILED
            policy = policy[0]

        # Only string references are valid (not inline JSON objects)
        if not isinstance(policy, str):
            return CheckResult.FAILED

        # Check for data source reference pattern
        # Must contain both the data source and .json attribute
        if "data.aws_iam_policy_document." in policy and policy.endswith(".json"):
            return CheckResult.PASSED

        return CheckResult.FAILED


check = EcrPolicyUsesDataSource()
