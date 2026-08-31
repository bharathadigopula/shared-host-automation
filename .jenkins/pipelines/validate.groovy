//==============================================================================
// SHARED HOST AUTOMATION VALIDATION
//==============================================================================

@Library('jenkins-pipeline-templates@v1.2.0') _

repositoryValidationPipeline(
    shellSearchPath: 'scripts',
    validationScript: 'scripts/validate.sh',
    validateWorkflows: true
)