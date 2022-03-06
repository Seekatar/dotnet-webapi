# Checklist for Setting up the K8s Cluster

The "Windows" box is the one used for development and could be other OSes.

## Windows Step 1

- [ ] Clone this repo
- [ ] Enable OpenSSH client
- [ ] Install client apps, docker(.exe), kubectl(.exe), helm(.exe)
- [ ] Create SSH key pair
- [ ] Install Raspberry Pi Imager
- [ ] Create the SD card for k3s-server
  - Use Raspberry-Pi Lite (headless)
  - Set hostname
  - Enable SSH and set the public key
  - Set username and password
  - Configure wifi
  - Set locale settings
- [ ] Create the SD card for k3s-worker-1
  - Use same settings as above except hostname

## k3s-server

- [ ] Set static IP to x.x.x.200 in `/etc/dhcpcd.conf`
- [ ] In `/boot/cmdline.txt` and add `cgroup_memory=1 cgroup_enable=memory`
- [ ] Disable swap

    ```bash
    sudo service dphys-swapfile stop
    sudo systemctl disable dphys-swapfile.service
    ```

- [ ] `sudo reboot`
- [ ] Install K3s `curl -sfL https://get.k3s.io | sh -`
- [ ] Copy `/var/lib/rancher/k3s/server/node-token` locally
- [ ] Copy `/etc/rancher/k3s/k3s.yaml` to `~/.kube/k3s-config` locally
- [ ] Install Docker `curl -sSL https://get.docker.com | sh`
- [ ] Install Docker Registry ``
- [ ] Add Registry Mirror. Edit `/etc/rancher/k3s/registries.yaml`

    ```yaml
    mirrors:
    "k3s-server:5000":
        endpoint:
        - "http://k3s-server:5000"
    ```

## k3s-worker-n

- [ ] Set static IP to x.x.x.201 in `/etc/dhcpcd.conf`
- [ ] In `/boot/cmdline.txt` and add `cgroup_memory=1 cgroup_enable=memory`
- [ ] Disable swap

    ```bash
    sudo service dphys-swapfile stop
    sudo systemctl disable dphys-swapfile.service
    ```

- [ ] `sudo reboot`
- [ ] Install K3s

    ```bash
    export K3S_TOKEN="<token from server's /var/lib/rancher/k3s/server/node-token>"
    export K3S_SERVER="https://<server's static ip>:6443"
    curl -sfL https://get.k3s.io | K3S_URL=$K3S_SERVER K3S_TOKEN=$K3S_TOKEN sh -
    ```

- [ ] Add Registry Mirror. Edit `/etc/rancher/k3s/registries.yaml`

    ```yaml
    mirrors:
    "k3s-server:5000":
        endpoint:
        - "http://k3s-server:5000"
    ```

## Windows Step 2

- [ ] Edit `~/.kube/k3s-config` to set `localhost` to `k3s-server`
- [ ] Set kubectl/helm default context `$env:KUBECONFIG='~/.kube/k3s-config'`
- [ ] Create docker context `docker context create k3s-server --docker "host=ssh://pi@k3s-server"`
- [ ] Set default docker context `docker context use k3s-server`
- [ ] Verify install

    ```bash
    kubectl version
    kubectl cluster-info
    kubectl get nodes -o wide
    ```

- [ ] Deploy with helm `.\run.ps1 buildDocker,pushDocker,uninstallHelm,installHelm  -Tag 01a`
