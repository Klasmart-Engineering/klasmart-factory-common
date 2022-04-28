# load extensions
load('ext://git_resource', 'git_checkout')
load('./utils/Tiltfile', 'info')
load('./utils/Tiltfile', 'warn_missing_repo')


# required
# include('./common-infrastructure/Tiltfile')

# every service requires a helm chart from the central repository
if not os.path.exists('../microgateway-base-helm'):
    git_checkout('git@github.com:KL-Infrastructure/microgateway-base-helm', '../microgateway-base-helm')
else:
    info('skipping clone, the repository is already present: KL-Infrastructure/microgateway-base-helm')

# optional resources, load only when repositories exist at the given path
if os.path.exists('../microgateway-base-helm'):
    load_dynamic('./shared-gateway/Tiltfile')
else:
    warn_missing_repo('microgateway-base-helm')
