# Bridgehead Forward Proxy
The target of this project is to provide a local service for components running inside restricted networks, that will handle all communication with corporate proxy. Therefore, components that can't handle different kind of proxys well by them selfe, can just refer to this standard proxy inside their docker network, and the bridgehead forward proxy will handle the rest.
The bridgehead forward proxy is a customized version of the squid cache proxy. Additionally, all communication of this proxy will wrap with proxy chains if a proxy is configured.
