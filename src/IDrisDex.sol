// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Import Uniswap V3 interfaces
import "./interfaces/IUniswapV3Router.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH9.sol";

contract IDrisDEX {
    IUniswapV3Router public immutable swapRouter;
    IWETH9 public immutable WETH9;

    // Uniswap V3 Router address for Ethereum mainnet
    address private constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant WETH9_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH9 contract address

    // Constructor to initialize the Uniswap V3 router and WETH9 contract
    constructor() {
        swapRouter = IUniswapV3Router(UNISWAP_V3_ROUTER_ADDRESS);
        WETH9 = IWETH9(WETH9_ADDRESS);
    }

    // Function to swap an exact amount of input tokens for as many output tokens as possible
    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee, // Uniswap V3 fee tier (e.g., 3000 = 0.30%)
        address recipient,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        // Transfer the specified amount of tokenIn to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approve the Uniswap V3 router to spend the tokens
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        // Set up the parameters for the swap
        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: deadline,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0 // Set to 0 to ignore the price limit
         });

        // Execute the swap
        amountOut = swapRouter.exactInputSingle(params);
    }

    // Function to swap as little input tokens as possible to get an exact amount of output tokens
    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        address recipient,
        uint256 amountOut, // Exact amount of tokenOut you want to receive
        uint256 amountInMaximum, // Maximum amount of tokenIn you're willing to spend
        uint256 deadline
    ) external returns (uint256 amountIn) {
        // Transfer the maximum amount of tokenIn to this contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountInMaximum);

        // Approve the Uniswap V3 router to spend the tokens
        IERC20(tokenIn).approve(address(swapRouter), amountInMaximum);

        // Set up the parameters for the swap
        IUniswapV3Router.ExactOutputSingleParams memory params = IUniswapV3Router.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: recipient,
            deadline: deadline,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum,
            sqrtPriceLimitX96: 0
        });

        // Execute the swap and return the amount of tokenIn spent
        amountIn = swapRouter.exactOutputSingle(params);

        // If there is leftover tokenIn, refund it to the user
        if (amountIn < amountInMaximum) {
            IERC20(tokenIn).transfer(msg.sender, amountInMaximum - amountIn);
        }
    }

    // Function to wrap ETH into WETH
    function wrapETH() external payable {
        WETH9.deposit{ value: msg.value }(); // Wrap ETH into WETH
        WETH9.transfer(msg.sender, msg.value); // Send the WETH to the user
    }

    // Function to unwrap WETH back into ETH
    function unwrapWETH(uint256 amount) external {
        WETH9.transferFrom(msg.sender, address(this), amount); // Transfer WETH to this contract
        WETH9.withdraw(amount); // Unwrap WETH into ETH
        payable(msg.sender).transfer(amount); // Send the ETH to the user
    }

    // Receive ETH fallback function
    receive() external payable { }
}
