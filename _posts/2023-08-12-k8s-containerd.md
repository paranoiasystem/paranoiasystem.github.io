---
title: "Kubernetes e containerd: Un Matrimonio Perfetto"
category: Kubernetes
description: Scopri come combinare la potenza di Kubernetes con la leggerezza e l'efficienza di containerd. Una guida passo passo che ti accompagna nella creazione di un cluster perfetto, pronto per ogni sfida!
image: k8s-containerd/cover.jpg
keywords: Kubernetes, cluster, containerd, kubeadm, kubelet, kubectl
layout: post
date:   2023-08-12
---

In un mondo dove la containerizzazione sta diventando sempre più centrale, avere una solida comprensione di come configurare Kubernetes è essenziale. In questo articolo, ti guiderò passo passo attraverso l'installazione di un cluster Kubernetes usando `containerd` come runtime. E se ti stai chiedendo "Perché containerd?", la risposta è semplice: è leggero, efficiente e perfettamente integrato con Kubernetes.

---

Recentemente ho ricevuto la [ZimaBoard](https://www.zimaboard.com/). Motivato dall'entusiasmo di sperimentare, ho immediatamente installato Proxmox e ho creato un cluster Kubernetes con containerd come runtime. E così è nata l'idea di questo articolo.

Ho iniziato creando due macchine virtuali. Ecco le specifiche:

- Sistema operativo: Ubuntu 20.04
- CPU: 2 vCPU
- Memoria: 4GB
- Spazio su disco: 20GB

Prima di procedere, assicuriamoci che le nostre macchine virtuali possano comunicare tra loro. Una volta verificato, siamo pronti a iniziare.

## Installazione di containerd

Containerd è la spina dorsale del nostro cluster, le fondamenta su cui poggerianno tutti i nostri container. Installiamolo sulle nostre macchine:

**Prepariamoci all'installazione:**

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
```

**Aggiungiamo la chiave di firma ufficiale di Docker:**

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

**Aggiungiamo il repository ufficiale di Docker al nostro elenco di sorgenti:**

```bash
echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**Installiamo finalmente containerd:**

```bash
sudo apt-get update
sudo apt-get install containerd.io -y
```

## Installazione di kubeadm, kubelet e kubectl

Questi tre componenti sono il cuore pulsante di Kubernetes. `kubeadm` ci aiuta a configurare il cluster, mentre `kubelet` si assicura che tutti i container vengano eseguiti correttamente. `kubectl` è la nostra interfaccia di comando, con cui daremo ordini al nostro cluster.

```bash
curl -fsSL https://dl.k8s.io/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
```

```bash
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

## Disabilitare lo Swap

Kubernetes preferisce che lo swap sia disabilitato, in quanto può interferire con la programmazione dei pod, in particolare in scenari in cui la memoria è limitata.

```bash
sudo swapoff -a
```

```bash
sudo nano /etc/fstab
```

(Nell'editor, commenta la riga che fa riferimento allo swap aggiungendo un `#` all'inizio della riga)

## Configurazione dei moduli kernel

Dobbiamo abilitare alcuni moduli del kernel Linux per far funzionare tutto correttamente.

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
```

```bash
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```

```bash
sudo sysctl --system
```

## Configurare containerd

Assicuriamoci che containerd sia configurato correttamente per interagire con Kubernetes:

```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

```bash
sudo systemctl restart containerd
sudo systemctl enable containerd
```

## Configurazione del control plane

Ecco il momento più eccitante! Stiamo per inizializzare il nostro cluster Kubernetes.

```bash
sudo systemctl enable kubelet
```

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

(Non dimenticare di annotare il comando di join mostrato all'output! Lo useremo per aggiungere altri nodi al cluster.)

## Installazione di Calico come CNI

Calico è uno dei più popolari Network Interface per Kubernetes. Aiuta a gestire la comunicazione tra pod.

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml
```

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml
```

---

Se sei arrivato fino a qui, hai ora un cluster Kubernetes funzionante con `containerd` come runtime. Spero che questo articolo ti sia tornato utile, e se hai domande o suggerimenti, non esitare a [contattarmi](https://www.linkedin.com/in/marcoferraioli93/).