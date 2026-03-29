import { RpcProvider, Contract, Account, uint256, CallData } from "starknet";

export const STARKNET_RPC = "https://starknet-sepolia.public.blastapi.io/rpc/v0_7";

export const provider = new RpcProvider({nodeUrl: STARKNET_RPC});
export const ESCROW_CONTRACT_ADDRESS = process.env.NEXT_PUBLIC_ESCROW_CONTRACT_ADDRESS || "0x0";

export const ESCROW_ABI = [
  {
    type: "function",
    name: "deposit",
    inputs: [
      { name: "worker", type: "core::starknet::contract_address::ContractAddress" },
      { name: "amount", type: "core::integer::u256" },
      { name: "work_cid", type: "core::felt252" },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "release_payment",
    inputs: [
      { name: "job_id", type: "core::felt252" },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "get_job",
    inputs: [{ name: "job_id", type: "core::felt252" }],
    outputs: [
      {
        type: "tuple",
        members: [
          { name: "employer", type: "core::starknet::contract_address::ContractAddress" },
          { name: "worker", type: "core::starknet::contract_address::ContractAddress" },
          { name: "amount", type: "core::integer::u256" },
          { name: "work_cid", type: "core::felt252" },
          { name: "is_released", type: "core::bool" },
        ],
      },
    ],
    state_mutability: "view",
  },
] as const;