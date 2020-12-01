Name:       dict
Version:    %VERSION
Release:    %{?GITTAG}%{?dist}
Summary:    Vhost Forwarder.
Group:      System Environment/Storage
License:    BSD License
URL:        http://www.github.com
Source0:    %{ARCHIVE}
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

## Disable debug packages.
%define         debug_package %{nil}

%description
A tiny dictionary tool on the console.

%prep
%setup -qc

%build
make

%install
rm -rf ${RPM_BUILD_ROOT}
install -d ${RPM_BUILD_ROOT}%{_sbindir}

install -p -m 6755 dict ${RPM_BUILD_ROOT}%{_sbindir}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%{_sbindir}/dict

%changelog
%(git log -n 10 --format="%ct * %cd %aN\n- (%h) %s%d%n" --date=local | sort -r | sed -r 's/[0-9]+:[0-9]+:[0-9]+ //' | cut -d" " -f2- | sed -e "s/\\\n/\\`echo -e '\n\r'`/g" | tr -d '\15\32')
