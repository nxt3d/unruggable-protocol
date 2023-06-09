//SPDX-License-Identifier: MIT 
pragma solidity >=0.8.19<0.9.0;

//import "forge-std/console.sol";
import {IExtendedResolver} from "./IExtendedResolver.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IOwnableBook} from "./IOwnableBook.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IENSBookResolver} from "./IENSBookResolver.sol";

error CannotResolve(bytes4 selector);

contract ENSBookResolver is Ownable(msg.sender), IExtendedResolver, IENSBookResolver, ERC165{

    // The Book to resolve the ENS names to.
    IOwnableBook public book;

    // A mapping of ENS Coin Types to addresses.
    mapping(uint256 coinType => address _address) public ensAddresses;

    // addr(bytes32 node, uint256 coinType) public view virtual override returns (bytes memory) 
    // => addr(bytes32,uint256) => 0xf1cb7e06
    // addr( bytes32 node) public view virtual override returns (address payable) {
    // => addr(bytes32) => 0x3b3b57de 
    // text(bytes32 node, string calldata key)external view virtual override returns (string memory)
    // => text(bytes32,string) => 0x59d1d43c
    // contenthash(bytes32 node) external virtual authorised(node) 
    // contenthash( bytes32 node) external view virtual override returns (bytes memory) 
    // => contenthash(bytes32) => 0xbc1c58d1


    // Set the book using the constructor.

    constructor(address _book) {
        book = IOwnableBook(_book);
    }

    /**
    * @dev A function to resolve an ENS name. The name parameter is ignored.
    * @param data data The data to resolve.
     */

    function resolve(bytes calldata, bytes calldata data)
        external
        view
        override (IExtendedResolver, IENSBookResolver)
        returns (bytes memory, address)
    {

        // Read function selector from the data.
        bytes4 selector = bytes4(data[0:4]);    

        // There is no address resolution for books because we don't want to allow sending of funds to books.

        // Resolve address.
        if (selector == 0xf1cb7e06 || selector == 0x3b3b57de) {

            // The ENS Coin Type.
            uint256 coinType;

            // If the selector is the addr(bytes32) function (without a coin type) then set the coin type to ETH (60).
            if (selector == 0x3b3b57de){
                coinType = 60;
            } else {
                // selector: addr(bytes32,uint256)
                // Decode the ABI encoded function call (data).
                // Save the coin type and not the function selector or node.
                ( , coinType) = abi.decode(data[4:], (bytes32, uint256));
            }

            // Return the resolved address.
            return (abi.encode(ensAddresses[coinType]), address(this)); 

        } else if (selector == 0x59d1d43c) {
            //Resolve text records.
            // Strip off the function selector and decode the ABI encoded function call (data).
            ( ,string memory key) = abi.decode(data[4:], (bytes32, string));

            // Check if the key is "avatar" and if so use the "Cover" page.
            if (areStringsEqual(key, "avatar")){

                // Return the text record. 
                return (abi.encode(bytes(book.pages("Cover"))), address(this));

            } else {

                // Return the text record. 
                return (abi.encode(bytes(book.pages(key))), address(this));
            }

        } else if (selector == 0xbc1c58d1) {
            //Resolve contenthash.

            // Return the text record. 
            return (abi.encode(bytes(book.pages("Book"))), address(this));

        } else { 
            revert CannotResolve(bytes4(selector));
        }
    } 

    /**
    * @dev A function to add an address for ENS resolution.
    * @param coinType The ENS Coin Type.
    * @param _address The address to add.
     */

    function addEnsAddress(uint256 coinType, address _address) public onlyOwner {
        ensAddresses[coinType] = _address;
    }

    function areStringsEqual(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override 
        returns (bool)
    {
        return interfaceId == type(IExtendedResolver).interfaceId ||
            interfaceId == type(IENSBookResolver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}