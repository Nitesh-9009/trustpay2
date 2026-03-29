// src/lib.cairo — TrustPay Escrow Contract

use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct Job {
    pub employer: ContractAddress,
    pub worker: ContractAddress,
    pub amount: u256,
    pub work_cid: felt252,
    pub is_released: bool,
    pub is_disputed: bool,
}

#[starknet::interface]
pub trait ITrustPayEscrow<TContractState> {
    fn deposit(
        ref self: TContractState,
        job_id: felt252,
        worker: ContractAddress,
        work_cid: felt252
    );
    fn submit_work_cid(ref self: TContractState, job_id: felt252, cid: felt252);
    fn release_payment(ref self: TContractState, job_id: felt252);
    fn get_job(self: @TContractState, job_id: felt252) -> Job;
    fn get_job_count(self: @TContractState) -> u64;
}

#[starknet::contract]
pub mod TrustPayEscrow {
    use super::{ContractAddress, Job, ITrustPayEscrow};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        Map, StorageMapReadAccess, StorageMapWriteAccess
    };
    use starknet::{get_caller_address, get_contract_address};

    // ✅ Use the ERC20ABI dispatcher which includes both transfer and transfer_from
    use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

    // STRK token on Sepolia testnet
    const STRK_TOKEN: felt252 =
        0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d;

    #[storage]
    struct Storage {
        jobs: Map<felt252, Job>,
        job_count: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        JobCreated: JobCreated,
        WorkSubmitted: WorkSubmitted,
        PaymentReleased: PaymentReleased,
    }

    #[derive(Drop, starknet::Event)]
    struct JobCreated {
        #[key]
        job_id: felt252,
        employer: ContractAddress,
        worker: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct WorkSubmitted {
        #[key]
        job_id: felt252,
        cid: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct PaymentReleased {
        #[key]
        job_id: felt252,
        worker: ContractAddress,
        amount: u256,
    }

    #[abi(embed_v0)]
    impl TrustPayEscrowImpl of ITrustPayEscrow<ContractState> {

        fn deposit(
            ref self: ContractState,
            job_id: felt252,
            worker: ContractAddress,
            work_cid: felt252
        ) {
            let caller = get_caller_address();
            let amount: u256 = 10_000_000_000_000_000_000; // 10 STRK

            // ✅ ERC20ABIDispatcher has transfer_from
            let strk = ERC20ABIDispatcher {
                contract_address: STRK_TOKEN.try_into().unwrap()
            };
            strk.transfer_from(caller, get_contract_address(), amount);

            self.jobs.write(
                job_id,
                Job {
                    employer: caller,
                    worker: worker,
                    amount: amount,
                    work_cid: work_cid,
                    is_released: false,
                    is_disputed: false,
                }
            );

            self.job_count.write(self.job_count.read() + 1);

            self.emit(JobCreated {
                job_id: job_id,
                employer: caller,
                worker: worker,
                amount: amount,
            });
        }

        fn submit_work_cid(ref self: ContractState, job_id: felt252, cid: felt252) {
            let caller = get_caller_address();
            let mut job = self.jobs.read(job_id);

            assert(caller == job.worker, 'Only worker can submit');
            assert(!job.is_released, 'Job already paid');

            job.work_cid = cid;
            self.jobs.write(job_id, job);

            self.emit(WorkSubmitted { job_id: job_id, cid: cid });
        }

        fn release_payment(ref self: ContractState, job_id: felt252) {
            let caller = get_caller_address();
            let mut job = self.jobs.read(job_id);

            assert(caller == job.employer, 'Only employer can release');
            assert(!job.is_released, 'Already released');
            assert(job.work_cid != 0, 'No work CID submitted yet');

            job.is_released = true;
            self.jobs.write(job_id, job);

            // ✅ ERC20ABIDispatcher has transfer
            let strk = ERC20ABIDispatcher {
                contract_address: STRK_TOKEN.try_into().unwrap()
            };
            strk.transfer(job.worker, job.amount);

            self.emit(PaymentReleased {
                job_id: job_id,
                worker: job.worker,
                amount: job.amount,
            });
        }

        fn get_job(self: @ContractState, job_id: felt252) -> Job {
            self.jobs.read(job_id)
        }

        fn get_job_count(self: @ContractState) -> u64 {
            self.job_count.read()
        }
    }
}