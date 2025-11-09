Name:           toucan
Version:        %{version}
Release:        1
Summary:        A static site generator (SSG) written in Swift
License:        MIT
URL:            https://github.com/toucansites/toucan
BuildArch:      %{?_target_cpu}
Source0:        %{name}-%{version}.tar.gz

%description
Toucan is a static site generator written in Swift.

%prep
%setup -q -c -T

%build
echo "Skipping build; using precompiled binaries."

%install
mkdir -p %{buildroot}/usr/local/bin
cp -a usr/local/bin/* %{buildroot}/usr/local/bin/

%files
%license LICENSE
%doc README.md
%dir /usr/local/bin
/usr/local/bin/*