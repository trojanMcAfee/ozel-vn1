pragma solidity 0.8.21;


import {Uint512} from "./Uint512.sol";

type UintRay is uint;

UintRay constant RAY = UintRay.wrap(1e27);
UintRay constant ZERO = UintRay.wrap(0);
UintRay constant TWO = UintRay.wrap(2);

using {equal as ==} for UintRay global;
using {power as ^} for UintRay global;

function equal(UintRay a, UintRay b) pure returns(bool) {
    return UintRay.unwrap(a) == UintRay.unwrap(b);
}

function power(UintRay a, UintRay b) pure returns(UintRay) {
    return UintRay.wrap(UintRay.unwrap(a) ** UintRay.unwrap(b));
}



library FixedPointMathRayLib {

    using Uint512 for uint;

    function mulDivRay(UintRay a, UintRay b, UintRay c) internal pure returns(UintRay) {
        uint aa = UintRay.unwrap(a);
        uint bb = UintRay.unwrap(b);
        uint cc = UintRay.unwrap(c);

        (uint r0, uint r1) = aa.mul256x256(bb);
        return UintRay.wrap(r0.div512x256(r1, cc));
    }

    function mulDiv512(uint a, uint b, uint c) internal pure returns(uint) {
        (uint r0, uint r1) = a.mul256x256(b);
        return r0.div512x256(r1, c);
    }

    function ray(uint num) internal pure returns(UintRay) {
        return UintRay.wrap(num * 1e27);
    }

    function unray(UintRay num) internal pure returns(uint) {
        return UintRay.unwrap(num) / 1e27;
    }

    function divUpRay(UintRay x, UintRay y) internal pure returns(uint) {
        uint xx = UintRay.unwrap(x);
        uint yy = UintRay.unwrap(y);

        return xx / yy + (xx % yy == 0 ? 0 : 1);
    }

}