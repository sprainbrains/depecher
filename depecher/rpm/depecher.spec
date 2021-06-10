Name:       depecher

%define theme sailfish-default

%{!?qtc_qmake:%define qtc_qmake %qmake}
%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}
Summary:    Telegram client for Sailfish OS
Version:    0.8.0
Release:    1
Group:      Applications/Communications
License:    LICENSE
URL:        https://github.com/blacksailer/depecher
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   tdlibjson >= 1.5.0
Requires:   libvorbis
Requires:   libdbusaccess
#Requires:   sailfish-version >= 4.0.0
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(openssl)
BuildRequires:  pkgconfig(tdlibjson)
BuildRequires:  pkgconfig(nemonotifications-qt5)
BuildRequires:  pkgconfig(vorbisfile)
BuildRequires:  pkgconfig(libdbusaccess)
BuildRequires:  pkgconfig(nemotransferengine-qt5)
BuildRequires:  sailfish-svg2png >= 0.1.5
BuildRequires:  desktop-file-utils

%description
Another Telegram client for Sailfish OS built on top of tdlib


%prep
%setup -q -n %{name}-%{version}

%build
%qtc_qmake5 

%qtc_make %{?_smp_mflags}


%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%post
systemctl-user stop org.blacksailer.depecher.service || true
if /sbin/pidof depecher > /dev/null; then
    killall depecher || true
fi

systemctl-user restart ngfd.service
#Moving db dir issue - #14
if [ -d "/home/nemo/depecherDatabase" ]; then
    if [ -e "/home/nemo/depecherDatabase/db.sqlite" ];then
        mv /home/nemo/depecherDatabase /home/nemo/.local/share/harbour-depecher
    fi
fi

systemctl-user daemon-reload
#systemctl-user enable org.blacksailer.depecher.service || true
#systemctl-user restart org.blacksailer.depecher.service || true

[ -z $LOGNAME ] && LOGNAME="$(loginctl --no-legend list-users | awk '{print $2}' | head -n1)"

if [ -f /home/$LOGNAME/.local/share/applications/mimeinfo.cache ]; then
    rm -f /home/$LOGNAME/.local/share/applications/mimeinfo.cache
    echo "Buggy app detected and 'fixed'"
fi

echo "Update desktop database"
update-desktop-database 2>&1 | grep -v x-maemo-highlight || true


%preun
systemctl-user stop org.blacksailer.depecher.service || true
systemctl-user disable org.blacksailer.depecher.service || true
systemctl-user daemon-reload
if /sbin/pidof depecher > /dev/null; then
    killall depecher || true
fi

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/applications/%{name}-openurl.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/lipstick/notificationcategories/*.conf
%{_datadir}/ngfd/events.d/*.ini
%exclude %{_libdir}/cmake/*
%exclude %{_libdir}/debug/*
%{_datadir}/dbus-1/services/org.blacksailer.depecher.service
%{_datadir}/dbus-1/interfaces/org.blacksailer.depecher.xml
%{_datadir}/jolla-settings/entries/%{name}.json
%{_prefix}/lib/systemd/user/org.blacksailer.depecher.service
%{_libdir}/nemo-transferengine/plugins/*
%{_sysconfdir}/%{name}/depecher-dbus-access.conf
%{_datadir}/themes/%{theme}/meegotouch/z1.0/icons/*.png
%{_datadir}/themes/%{theme}/meegotouch/z1.25/icons/*.png
%{_datadir}/themes/%{theme}/meegotouch/z1.5/icons/*.png
%{_datadir}/themes/%{theme}/meegotouch/z1.5-large/icons/*.png
%{_datadir}/themes/%{theme}/meegotouch/z1.75/icons/*.png
%{_datadir}/themes/%{theme}/meegotouch/z2.0/icons/*.png
