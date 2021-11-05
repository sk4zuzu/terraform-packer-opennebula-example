TERRAFORM-PACKER-OPENNEBULA-EXAMPLE
===================================

## 1. PURPOSE

Just a devops exercise.

## 2. INSTALL PACKER, TERRAFORM + PROVIDERS (NIXOS)

```
$ nix-shell --run "make requirements"
```

## 3. DEPLOY OPENNEBULA MINIONE NODE (NIXOS)

```
$ nix-shell --run "make opennebula"
```

## 4. DEPLOY ALPINE-BASED GUEST VM (NIXOS)

```
$ nix-shell --run "make guest"
```

## 5. CONNECT TO THE GUEST MACHINE

```
$ make ssh-guest
Warning: Permanently added '10.11.12.13' (ED25519) to the list of known hosts.
Warning: Permanently added '172.16.100.2' (ECDSA) to the list of known hosts.
localhost:~# uname -a
Linux localhost 5.10.61-0-virt #1-Alpine SMP Fri, 27 Aug 2021 05:29:55 +0000 x86_64 Linux
```
