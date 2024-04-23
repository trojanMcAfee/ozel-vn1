pragma solidity 0.8.21;


import {Uint512} from "./Uint512.sol";


library FixedPointMath512Lib {

    using Uint512 for uint;

    function mulDivDown512(uint a, uint b, uint c) internal pure returns(uint) {
        (uint r0, uint r1) = a.mul256x256(b);
        return r0.div512x256(r1, c);
    }

}