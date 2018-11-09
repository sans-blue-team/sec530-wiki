This diagram shows the addition of an explicit web proxy to the Tyrell Corporation architecture. In this example, web requests going outbound to the internet should come from the explicit web proxy.

![Tyrell Corp. network](Tyrell-3.0.png)

This diagram shows an adjustment in that the firewall is now a Next-Generation Firewall. In this example, the edge firewall is a NGFW and so is the internal firewall.

![Tyrell Corp. network](Tyrell-3.1.png)

This diagram shows the addition of multiple Network Security Monitor sensors to the Tyrell Corporation architecture. In this example, a sensor is in the DMZ with a tap sending a copy of traffic to it. Another sensor is within the internal server zone using network taps to receive traffic. Also, a sensor is in the corporate LAN zone with network traffic being received from a port mirror.

![Tyrell Corp. network](Tyrell-3.2.png)

This diagram shows the addition of a malware detonation device to the Tyrell Corporation architecture. In this example, content can be submitted to the malware detonation device as well as automatically extracted through network traffic visible from network taps.

![Tyrell Corp. network](Tyrell-3.3.png)

This diagram shows the addition of a decrypt port mirror and Network Security Monitor sensor to the Tyrell Corporation architecture. In this example, this allows for TLS traffic to be decrypted for the NGFW to inspect data and then a copy of the decrypted data to be sent to a Network Security Monitor.

![Tyrell Corp. network](Tyrell-3.4.png)

This diagram shows the addition of a SSL VPN with multifactor authentication requirements to the Tyrell Corporation architecture. In this example, users can remotely connect into the environment using the SSL VPN with multifactor authentication.

![Tyrell Corp. network](Tyrell-3.5.png)

Addition of a jump box in a separate segment.

![Tyrell Corp. network](Tyrell-3.6.png)

This diagram shows the addition of DDOS protection to the Tyrell Corporation architecture. In this example, requests to inbound services such as web services in the DMZ are routed through a DDOS scrubbing cloud service.

![Tyrell Corp. network](Tyrell-3.7.png)
