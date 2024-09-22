// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Importaciones de bibliotecas de OpenZeppelin que proporcionan funcionalidades seguras y modulares.
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";  // Interfaz para interactuar con contratos ERC721.
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";  // Permite que el contrato reciba tokens ERC721 de forma segura.
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";  // Módulo para control de propiedad de contratos "upgradeables".
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";  // Módulo para pausar el contrato en caso de emergencia.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";  // Previene ataques de reentrancia.
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";  // Permite que el contrato sea inicializable y actualizable.
import "@openzeppelin/contracts/proxy/Clones.sol";  // Biblioteca para crear clones de contratos con patrones de fábrica.

// Contrato del Marketplace de NFTs
contract NFTMarketplace is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuard {

    // Estructura que define un listado de NFT dentro del Marketplace
    struct Listing {
        address nftContract;  // Dirección del contrato ERC721 del NFT.
        uint256 tokenId;      // Identificador único del token NFT.
        address seller;       // Dirección del vendedor del NFT.
        uint256 price;        // Precio del NFT.
    }

    // Mapeo para almacenar los listados de NFT en el Marketplace.
    mapping(uint256 => Listing) public listings;

    // Contador para asignar un identificador único a cada listado de NFT.
    uint256 public listingCounter;

    // Dirección del contrato que creó el Marketplace, normalmente usado para actualizaciones.
    address public marketplaceFactory;

    // Eventos que notifican cuando ocurre una acción en el contrato.
    event NFTListed(uint256 indexed listingId, address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTPurchased(uint256 indexed listingId, address indexed buyer, uint256 price);
    event NFTTransferred(uint256 indexed listingId, address indexed seller, address indexed buyer);

    // Función que inicializa el contrato, configurando el propietario y otros parámetros.
    function initialize(address _marketplaceFactory) public initializer {
        marketplaceFactory = _marketplaceFactory;

        // Inicializa el módulo de propiedad con la dirección del propietario del contrato.
        __Ownable_init(msg.sender);

        // Inicializa el módulo de pausado sin necesidad de parámetros adicionales.
        __Pausable_init();
    }

    // Función para listar un NFT en el Marketplace.
    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price) external whenNotPaused nonReentrant {
        require(_price > 0, "El precio debe ser mayor a 0");  // El precio del NFT debe ser positivo.
        IERC721 nftContract = IERC721(_nftContract);  // Instancia del contrato ERC721.
        require(nftContract.ownerOf(_tokenId) == msg.sender, "No eres el propietario del NFT");  // Solo el propietario puede listar el NFT.
        require(nftContract.isApprovedForAll(msg.sender, address(this)) || nftContract.getApproved(_tokenId) == address(this), "Marketplace no aprobado para manejar el NFT");  // Verifica que el marketplace esté autorizado para manejar el NFT.

        // Almacena el nuevo listado en el mapeo.
        listings[listingCounter] = Listing(_nftContract, _tokenId, msg.sender, _price);

        // Emite el evento indicando que el NFT ha sido listado.
        emit NFTListed(listingCounter, msg.sender, _tokenId, _price);

        // Incrementa el contador de listados.
        listingCounter++;
    }

    // Función para comprar un NFT listado en el Marketplace.
    function buyNFT(uint256 _listingId) external payable whenNotPaused nonReentrant {
        Listing memory listing = listings[_listingId];  // Recupera los detalles del listado.
        require(msg.value >= listing.price, "No se ha enviado suficiente ETH");  // Verifica que el comprador haya enviado suficientes fondos.

        // Transfiere el NFT del vendedor al comprador.
        IERC721(listing.nftContract).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        // Envía el pago al vendedor.
        payable(listing.seller).transfer(listing.price);

        // Emite el evento indicando que el NFT ha sido comprado.
        emit NFTPurchased(_listingId, msg.sender, listing.price);
    }

    // Función para que el vendedor transfiera manualmente un NFT a otro usuario.
    function transferNFT(uint256 _listingId, address _to) external whenNotPaused nonReentrant {
        Listing memory listing = listings[_listingId];  // Recupera los detalles del listado.
        require(listing.seller == msg.sender, "Solo el vendedor puede transferir el NFT");  // Verifica que solo el vendedor original puede realizar la transferencia.

        // Transfiere el NFT al nuevo propietario.
        IERC721(listing.nftContract).safeTransferFrom(listing.seller, _to, listing.tokenId);

        // Emite el evento indicando que el NFT ha sido transferido.
        emit NFTTransferred(_listingId, listing.seller, _to);
    }

    // Función para pausar el contrato en caso de emergencia. Solo el propietario puede pausar.
    function pause() external onlyOwner {
        _pause();
    }

    // Función para reanudar el contrato cuando ya no se necesita la pausa. Solo el propietario puede reanudar.
    function unpause() external onlyOwner {
        _unpause();
    }
}

// Contrato de Fábrica para crear nuevos Marketplaces
contract NFTMarketplaceFactory is OwnableUpgradeable {
    address public implementation;  // Dirección del contrato base (implementación) que será clonado.

    // Evento que indica cuando un nuevo marketplace ha sido creado.
    event MarketplaceCreated(address indexed newMarketplace);

    // Constructor que establece la implementación del contrato base.
    constructor(address _implementation) {
        implementation = _implementation;
    }

    // Función para crear un nuevo Marketplace clonando la implementación.
    function createMarketplace() external onlyOwner {
        address clone = Clones.clone(implementation);  // Crea un nuevo clon del contrato.
        NFTMarketplace(clone).initialize(address(this));  // Inicializa el nuevo clon con la fábrica como argumento.
        emit MarketplaceCreated(clone);  // Emite el evento indicando que se ha creado un nuevo Marketplace.
    }

    // Función para actualizar la dirección del contrato de implementación.
    function updateImplementation(address _newImplementation) external onlyOwner {
        implementation = _newImplementation;  // Cambia la implementación del contrato base.
    }
}
