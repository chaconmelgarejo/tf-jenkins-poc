pipeline {
    agent any
    tools {
        "org.jenkinsci.plugins.terraform.TerraformInstallation" "terraform"
    }
    parameters {
        string(name: 'WORKSPACE', defaultValue: 'development', description:'workspace to use in Terraform')
    }

    environment {
        TF_HOME = tool('terraform')
        TF_INPUT = "0"
        TF_IN_AUTOMATION = "TRUE"
        TF_LOG = "WARN"
        AWS_ACCESS_KEY_ID = credentials('aws_access_key')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        PATH = "$TF_HOME:$PATH"
    }

    stages {
        stage('ApplicationInit'){
            steps {
                dir('infra-as-code/'){
                    sh 'terraform --version'
                    sh "terraform init"
                }
            }
        }
        stage('ApplicationValidate'){
            steps {
                dir('infra-as-code/'){
                    sh 'terraform validate'
                }
            }
        }
        stage('ApplicationPlan'){
            steps {
                dir('infra-as-code/'){
                    script {
                        try {
                           sh "terraform workspace new ${params.WORKSPACE}"
                        } catch (err) {
                            sh "terraform workspace select ${params.WORKSPACE}"
                        }
                        sh "terraform plan -out terraform-applications.tfplan;echo \$? > status"
                        stash name: "terraform-applications-plan", includes: "terraform-applications.tfplan"
                    }
                }
            }
        }
        stage('ApplicationApply'){
            steps {
                script{
                    def apply = false
                    try {
                        input message: 'confirm apply', ok: 'Apply Config'
                        apply = true
                    } catch (err) {
                        apply = false
                        dir('infra-as-code/'){
                            sh "terraform destroy -auto-approve"
                        }
                        currentBuild.result = 'UNSTABLE'
                    }
                    if(apply){
                        dir('infra-as-code/'){
                            unstash "terraform-applications-plan"
                            sh 'terraform apply terraform-applications.tfplan'
                        }
                    }
                }
            }
        }
    }
}