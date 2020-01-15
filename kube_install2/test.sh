kubeadm join 172.16.45.150:6443 --token 58sklr.ptxhsh3juu8lm4ni \
    --discovery-token-ca-cert-hash sha256:96475ec1bf3bc5eedc58ef54ccbf5796be7ea59844f682edc229d889651d5a76



tiller:v2.14.1


docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.14.1
docker tag ${MY_REGISTRY}/kube-apiserver:v1.17.0 k8s.gcr.io/kube-apiserver:v1.17.0


docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.14.1  gcr.io/kubernetes-helm/tiller:v2.14.1


yum list kubectl.x86_64

yum list kubectl.x86_64  --showduplicates |sort -r
yum list kubelet.x86_64  --showduplicates |sort -r
yum list kubeadm  --showduplicates |sort -r


yum install kubectl-1.15.1-0.x86_64
yum install kubelet-1.15.1-0.x86_64
yum install kubeadm-1.15.1-0.x86_64


helm install stable/nginx-ingress \
-n nginx-ingress \
--namespace kube-system  \
-f ingress-nginx.yaml


docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:0.27.0
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/nginx-ingress-controller:0.27.0 quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.27.0

docker pull registry.cn-hangzhou.aliyuncs.com/lusifeng/defaultbackend-amd64:1.5
docker tag registry.cn-hangzhou.aliyuncs.com/lusifeng/defaultbackend-amd64:1.5 k8s.gcr.io/defaultbackend-amd64:1.5



helm install stable/nginx-ingress \
-n nginx-ingress \
--namespace kube-system  \
--set controller.service.externalIPs[0]=172.16.45.150

172.16.45.150:30074
curl -I http://172.16.45.150/healthz/



