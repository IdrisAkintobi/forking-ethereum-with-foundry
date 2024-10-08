// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import { Script, console } from "forge-std/Script.sol";
import { IERC20 } from "../src/interfaces/IERC20.sol";
import { IUniswapV3Router } from "../src/interfaces/IUniswapV3Router.sol";
import "forge-std/console.sol";

contract UniswapSwap is Script {
    IUniswapV3Router constant router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Uniswap V3 Router
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC address
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI address
    address constant tokenHolder = 0xf584F8728B874a6a5c7A8d4d387C9aae9172D621; // The address to impersonate (whale account with a lot of USDC)

    uint256 constant DAI_UNIT = 1e18;
    uint256 constant USDC_UNIT = 1e6;

    function run() external {
        // Start impersonating the token holder (whale address)
        vm.startPrank(tokenHolder);

        uint256 amountOut = 10 * DAI_UNIT; // Amount of DAI we want (10 DAI)
        uint256 amountInMax = 100 * USDC_UNIT; // Maximum amount of USDC we're willing to spend (100 USDC)
        address recipient = tokenHolder; // Send the output tokens to the impersonated account
        uint256 deadline = block.timestamp + 10 minutes; // 10 minute deadline

        // Approve the Uniswap router to spend USDC
        IERC20(USDC).approve(address(router), amountInMax);

        uint256 USDCBalBefore = IERC20(USDC).balanceOf(tokenHolder);
        uint256 DAIBalBefore = IERC20(DAI).balanceOf(tokenHolder);

        // Swap parameters: we're swapping from USDC to DAI
        IUniswapV3Router.ExactOutputParams memory params = IUniswapV3Router.ExactOutputParams({
            path: abi.encodePacked(DAI, uint24(3000), USDC), // Path for swapping: USDC -> DAI with 0.30% fee
            recipient: recipient,
            deadline: deadline,
            amountOut: amountOut,
            amountInMaximum: amountInMax
        });

        // Perform the swap
        uint256 amountIn = router.exactOutput(params);

        uint256 USDCBalAfter = IERC20(USDC).balanceOf(tokenHolder);
        uint256 DAIBalAfter = IERC20(DAI).balanceOf(tokenHolder);

        //Balance before
        console.log("USDC Balance before::", USDCBalBefore / USDC_UNIT);
        console.log("DIA Balance before::", DAIBalBefore / DAI_UNIT);

        //Balance after
        console.log("USDC Balance after::", USDCBalAfter / USDC_UNIT);
        console.log("DIA Balance after::", DAIBalAfter / DAI_UNIT);

        // Logging the result using console.log
        console.log("Amount of USDC spent:", amountIn / USDC_UNIT);
        console.log("Amount of DAI received:", amountOut / DAI_UNIT);

        // Stop impersonating the token holder
        vm.stopPrank();
    }
}
