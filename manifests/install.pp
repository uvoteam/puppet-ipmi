
class ipmi::install (
    Array[String] $packages,
){
    ensure_packages([ $packages ])
}

