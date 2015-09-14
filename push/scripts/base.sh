mkdir -p /media/dvd
mount -o loop,ro VBoxGuestAdditions*.iso /media/dvd
sh /media/dvd/VBoxLinuxAdditions.run --nox11
umount /media/dvd
rm VBoxGuestAdditions*.iso
useradd vagrant
cp /etc/sudoers /etc/sudoers.orig
sed -i -e 's/Defaults\\s*requiretty$/#Defaults\trequiretty/' /etc/sudoers
sed -i -e '/# %wheel\tALL=(ALL)\tNOPASSWD: ALL/a %vagrant\tALL=(ALL)\tNOPASSWD: ALL' /etc/sudoers 
mkdir ~vagrant/.ssh 
chmod 700 ~vagrant/.ssh 
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key' > ~vagrant/.ssh/authorized_keys 
chmod 600 ~vagrant/.ssh/authorized_keys 
chown -R vagrant: ~vagrant/.ssh 
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.ori 
sed -i -e '/#UseDNS yes/a UseDNS no' /etc/ssh/sshd_config 
for nic in /etc/sysconfig/network-scripts/ifcfg-*; do sed -i /HWADDR/d $nic; sed -i /UUID/d $nic || true ; done 
[ -f /etc/udev/rules.d/70-persistent-net.rules ] && rm /etc/udev/rules.d/70-persistent-net.rules 
echo "Defaults !requiretty" >> /etc/sudoers
history -c 
true