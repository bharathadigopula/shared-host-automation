//==============================================================================
// SHARED HOST AUTOMATION VALIDATION
//==============================================================================

@Library('jenkins-pipeline-templates@v1.4.0') _

repositoryValidationPipeline(
    githubRepository: 'bharathadigopula/shared-host-automation',
    shellSearchPath: 'scripts',
    validationScript: 'scripts/validate.sh',
    validateWorkflows: true
)