// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// asset - 0x5e17b14ADd6c386305A32928F985b29bbA34Eff5 18
// LiquidityToken - 0x3328358128832A260C76A4141e19E2A943CD4B6D 6
// LiquidityProvider - 0xe2899bddFD890e320e643044c6b95B9B0b84157A

interface ILiquidityProvider {
    function liquidityToken() external view returns (ERC20);
}

contract Erc20Token is ERC20 {
    uint8 _decimals = 18;

    constructor(uint8 decimals_) ERC20("name", "symbol") {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

contract LiquidityProvider is ILiquidityProvider {
    ERC20 public liquidityProvider;

    function updateLiquidityProvider(address liquidityProviderAddress)
        external
    {
        liquidityProvider = ERC20(liquidityProviderAddress);
    }

    function liquidityToken() external view returns (ERC20) {
        return liquidityProvider;
    }
}

contract SecuritizeRedemption {
    ILiquidityProvider public liquidityProvider;
    ERC20 public asset;

    uint256 cachedLiquidityDecimals;
    uint256 cachedAssetDecimals;

    function updateLiquidityProvider(address _liquidityProvider) external {
        liquidityProvider = ILiquidityProvider(_liquidityProvider);

        address liquidityTokenAddress = address(
            liquidityProvider.liquidityToken()
        );

        cachedLiquidityDecimals = ERC20(liquidityTokenAddress).decimals();
        cachedAssetDecimals = ERC20(address(asset)).decimals();
    }

    function updateAsset(address _asset) external {
        asset = ERC20(_asset);
    }

    // 23203
    function calculateOrig() public view returns (uint256) {
        uint256 _amount = 1000000000000000000;
        uint256 rate = 2000000;

        address liquidityTokenAddress = address(
            liquidityProvider.liquidityToken()
        );
        uint256 liquidityDecimals = ERC20(liquidityTokenAddress).decimals();

        uint256 assetDecimals = ERC20(address(asset)).decimals();

        if (liquidityDecimals > assetDecimals) {
            return
                ((_amount * rate) * (10**(liquidityDecimals - assetDecimals))) /
                (10**liquidityDecimals);
        }
        if (liquidityDecimals < assetDecimals) {
            return
                (_amount * rate) /
                (10**(assetDecimals - liquidityDecimals)) /
                (10**liquidityDecimals);
        }
        return (_amount * rate) / (10**assetDecimals);
    }

    // 23193
    function calculateWithScalingFactor() public view returns (uint256) {
        uint256 _amount = 1000000000000000000;
        uint256 rate = 2000000;

        address liquidityTokenAddress = address(
            liquidityProvider.liquidityToken()
        );
        uint256 liquidityDecimals = ERC20(liquidityTokenAddress).decimals();

        uint256 assetDecimals = ERC20(address(asset)).decimals();

        uint256 scalingFactor;
        if (liquidityDecimals > assetDecimals) {
            scalingFactor = 10**(liquidityDecimals - assetDecimals);
            return ((_amount * rate) * scalingFactor) / (10**liquidityDecimals);
        }
        if (liquidityDecimals < assetDecimals) {
            scalingFactor = 10**(assetDecimals - liquidityDecimals);
            return (_amount * rate) / scalingFactor / (10**liquidityDecimals);
        }
        return (_amount * rate) / (10**assetDecimals);
    }

    // 6833
    function calculateWithCachedDecimals() public view returns (uint256) {
        uint256 _amount = 1000000000000000000;
        uint256 rate = 2000000;

        if (cachedLiquidityDecimals > cachedAssetDecimals) {
            return
                ((_amount * rate) *
                    (10**(cachedLiquidityDecimals - cachedAssetDecimals))) /
                (10**cachedLiquidityDecimals);
        }
        if (cachedLiquidityDecimals < cachedAssetDecimals) {
            return
                (_amount * rate) /
                (10**(cachedAssetDecimals - cachedLiquidityDecimals)) /
                (10**cachedLiquidityDecimals);
        }
        return (_amount * rate) / (10**cachedAssetDecimals);
    }

    // 6889
    function calculateWithCachedDecimalsAndScalingFactor()
        public
        view
        returns (uint256)
    {
        uint256 _amount = 1000000000000000000;
        uint256 rate = 2000000;

        uint256 scalingFactor;
        if (cachedLiquidityDecimals > cachedAssetDecimals) {
            scalingFactor = 10**(cachedLiquidityDecimals - cachedAssetDecimals);
            return
                ((_amount * rate) * scalingFactor) /
                (10**cachedLiquidityDecimals);
        }
        if (cachedLiquidityDecimals < cachedAssetDecimals) {
            scalingFactor = 10**(cachedAssetDecimals - cachedLiquidityDecimals);
            return
                (_amount * rate) /
                scalingFactor /
                (10**cachedLiquidityDecimals);
        }
        return (_amount * rate) / (10**cachedAssetDecimals);
    }
}
