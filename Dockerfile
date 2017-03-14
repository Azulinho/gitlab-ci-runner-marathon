FROM gitlab/gitlab-runner:ubuntu-v1.11.1

MAINTAINER TobiLG <tobilg@gmail.com>

RUN apt-get update && apt-get install -y \
        curl \
        dnsutils \
        apt-transport-https \
        software-properties-common \
        ca-certificates && \
    curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add - && \
    add-apt-repository \
        "deb https://apt.dockerproject.org/repo/ ubuntu-$(lsb_release -cs) main" && \
     apt-get update && apt-get install -y -q docker-engine=1.11.2-0~trusty && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -cL https://raw.githubusercontent.com/tobilg/mesosdns-resolver/master/mesosdns-resolver.sh > /usr/bin/mesosdns-resolver && \
    chmod +x /usr/bin/mesosdns-resolver

ADD register_and_run.sh /

ENTRYPOINT ["/register_and_run.sh"]