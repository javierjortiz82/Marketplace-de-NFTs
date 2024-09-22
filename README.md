# Marketplace de NFTs - Solidity Smart Contract

---

## Integrantes del equipo

**Perfiles de GitHub de los miembros del equipo**
1. **Javier Josué Ortiz Leon.**  
   **Perfil:** javierjortiz82

## Descripción del Contrato
Este repositorio contiene el desarrollo de un **Marketplace de NFTs** en Solidity. El contrato permite a los usuarios listar, comprar y transferir tokens ERC721 (NFTs). Además, se ha implementado un sistema de fábrica que permite crear múltiples marketplaces mediante clones de una implementación base, lo que facilita la actualización de funcionalidades y la creación de nuevos marketplaces con configuraciones similares.

### Funcionalidades principales:
1. **Listado de NFTs**: Los usuarios pueden listar sus NFTs a la venta, estableciendo un precio.
2. **Compra de NFTs**: Cualquier usuario puede comprar un NFT listado enviando la cantidad adecuada de ETH.
3. **Transferencia manual de NFTs**: Los vendedores también pueden transferir manualmente sus NFTs a otra dirección.
4. **Control de propiedad**: Solo el propietario del contrato puede pausar o reanudar la operación del marketplace.
5. **Funcionalidad de fábrica**: Permite crear nuevos marketplaces usando un patrón de clonación de contratos.

## Razonamiento detrás del diseño

### Patrones de diseño utilizados y razones:

1. **OwnableUpgradeable**:
   - **Propósito**: Controla las funciones administrativas críticas al asegurar que solo el propietario del contrato pueda ejecutarlas. Esto incluye operaciones como pausar o actualizar el contrato.
   - **Razón para usarlo**: Necesitamos un mecanismo seguro para otorgar permisos administrativos y la capacidad de transferir la propiedad del contrato en caso de ser necesario. `OwnableUpgradeable` es especialmente útil para contratos que se pueden actualizar, permitiendo que el propietario inicial administre el sistema de manera segura.

2. **PausableUpgradeable**:
   - **Propósito**: Permite pausar o reanudar la ejecución de ciertas funciones del contrato, como la compra o listado de NFTs, en caso de emergencia.
   - **Razón para usarlo**: Es importante tener un control sobre las operaciones del contrato en caso de detectar comportamientos inusuales o ataques. `PausableUpgradeable` facilita esta capacidad de gestión del sistema sin necesidad de interrumpir completamente el contrato.

3. **ReentrancyGuard**:
   - **Propósito**: Protege las funciones del contrato frente a ataques de reentrada, donde un atacante podría intentar realizar múltiples retiros simultáneos antes de que el saldo se actualice.
   - **Razón para usarlo**: Dado que el contrato maneja transacciones de compra y venta de NFTs, es fundamental prevenir ataques que busquen explotar vulnerabilidades de reentrada. `ReentrancyGuard` asegura que las funciones críticas como `buyNFT` sean seguras y no vulnerables a este tipo de exploits.

4. **Upgradeable Contracts (Initializable)**:
   - **Propósito**: Permite que el contrato sea actualizable en el futuro sin perder el estado almacenado, gracias al uso de proxies y contratos inicializables.
   - **Razón para usarlo**: En un entorno cambiante, es probable que las funcionalidades del marketplace necesiten mejoras o correcciones. Los contratos `upgradeable` permiten actualizar la lógica del contrato sin necesidad de redeployar toda la plataforma y perder el estado, como los listados activos o los dueños de los NFTs.

5. **Factory Pattern**:
   - **Propósito**: Permite crear múltiples instancias de marketplaces a partir de un contrato base (implementación) utilizando clones, lo que es eficiente en términos de gas y almacenamiento.
   - **Razón para usarlo**: Este patrón permite escalar la creación de marketplaces sin tener que desplegar un nuevo contrato completo cada vez. Usando clones, se puede replicar el contrato base ahorrando recursos y tiempo, además de garantizar que cada marketplace clonado se comporta de manera idéntica a la implementación original.

## Instrucciones de uso
1. Desplegar el contrato base `NFTMarketplaceFactory`.
2. Crear nuevos marketplaces mediante la función `createMarketplace()` de la fábrica.
3. Los usuarios pueden listar, comprar y transferir NFTs en cada marketplace desplegado.
