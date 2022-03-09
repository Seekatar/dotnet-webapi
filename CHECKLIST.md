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

- [ ] `sudo nano /etc/dhcpcd.conf` to set static IP to x.x.x.200
- [ ] `sudo nano /boot/cmdline.txt` and add `cgroup_memory=1 cgroup_enable=memory`
- [ ] Disable swap

    ```bash
    sudo service dphys-swapfile stop
    sudo systemctl disable dphys-swapfile.service
    ```

- [ ] `sudo reboot`
- [ ] `curl -sfL https://get.k3s.io | sh -` to install K3s
- [ ] `sudo cat /var/lib/rancher/k3s/server/node-token` and copy locally
- [ ] `sudo cat /etc/rancher/k3s/k3s.yaml` and save to `~/.kube/k3s-config` locally
- [ ] `curl -sSL https://get.docker.com | sh` to install Docker. It will warn about non-root docker
- [ ] `sudo usermod -aG docker $USER` to add current user (pi) to Docker group
- [ ] `docker run -d -p 5000:5000 --restart always --name registry registry:2` to install Docker Registry
- [ ] `sudo nano /etc/rancher/k3s/registries.yaml` to add Registry Mirror.

    ```yaml
    mirrors:
      "k3s-server:5000":
        endpoint:
        - "http://k3s-server:5000"
    ```

- [ ] `sudo systemctl restart k3s`

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
    export K3S_SERVER="https://<ipaddress of server>:6443"
    curl -sfL https://get.k3s.io | K3S_URL=$K3S_SERVER K3S_TOKEN=$K3S_TOKEN sh -
    ```

- [ ] `sudo nano /etc/rancher/k3s/registries.yaml` to add Registry Mirror.

    ```yaml
    mirrors:
      "k3s-server:5000":
        endpoint:
        - "http://k3s-server:5000"
    ```
- [ ] `sudo systemctl restart k3s-agent`

## Windows Step 2

- [ ] `code ~/.kube/k3s-config` and change `localhost` to `k3s-server`
- [ ] `$env:KUBECONFIG='~/.kube/k3s-config'` to set kubectl/helm default context
- [ ] `docker context create k3s-server --docker "host=ssh://pi@k3s-server"` to create docker context
- [ ] `docker context use k3s-server` to set the default docker context
- [ ] Verify install

    ```bash
    kubectl version
    kubectl cluster-info
    kubectl get nodes -o wide
    ```

- [ ] `.\run.ps1 buildDocker,pushDocker,uninstallHelm,installHelm  -Tag 01a` to deploy with web-api via helm
- [ ] Hit the deployed app [http://k3s-server/web-api/weatherforecast](http://k3s-server/web-api/weatherforecast)
