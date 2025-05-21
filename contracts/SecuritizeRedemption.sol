// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// asset - 0xb27A31f1b0AF2946B7F582768f03239b1eC07c2c 18
// LiquidityToken - 0xcD6a42782d230D7c13A74ddec5dD140e55499Df9 6
// LiquidityProvider - 0xaE036c65C649172b43ef7156b009c6221B596B8b

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

    // 23136
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

    // 6867
    function calculateWithCachedDecimals() public view returns (uint256) {
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
