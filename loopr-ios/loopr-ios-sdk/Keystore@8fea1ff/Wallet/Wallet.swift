// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import TrezorCrypto

/// A hierarchical deterministic wallet.
public class Wallet {
    public static let defaultPath = "m/44'/60'/0'/0/x"

    /// Wallet seed.
    public var seed: Data

    /// Mnemonic word list.
    public var mnemonic: String

    /// Derivation path.
    public var path: String

    /// Initializes a wallet from a mnemonic string and a password.
    public init(mnemonic: String, password: String, path: String = Wallet.defaultPath) {
        seed = Mnemonic.deriveSeed(mnemonic: mnemonic, password: password)
        self.mnemonic = mnemonic
        self.path = path
    }

    /// Initializes a wallet from a wallet seed.
    public init(seed: Data, path: String = Wallet.defaultPath) {
        self.seed = seed
        self.mnemonic = Mnemonic.generate(from: seed)
        self.path = path
    }

    private func getDerivationPath(for index: Int) -> DerivationPath {
        guard let path = DerivationPath(path.replacingOccurrences(of: "x", with: String(index))) else {
            preconditionFailure("Invalid derivation path string")
        }
        return path
    }

    private func getNode(for derivationPath: DerivationPath) -> HDNode {
        var node = HDNode()
        hdnode_from_seed(seed.bytes, Int32(seed.count), "secp256k1", &node)
        for index in derivationPath.indices {
            hdnode_private_ckd(&node, index.derivationIndex)
        }
        return node
    }

    /// Generates the key at the specified derivation path index.
    public func getKey(at index: Int) -> HDKey {
        let node = getNode(for: getDerivationPath(for: index))
        return HDKey(node: node)
    }
    
    /// Used in Relay API
    public static func generateRandomWallet() -> (privateKey: String, address: String) {
        // takes 35 seconds
        /*
        // Password is used inside KeystoreKey to generate a private key.
        let password = "12345678"
        let keystoreKey = try! KeystoreKey(password: password)
        
        // Get Private key
        let decrypted = try! keystoreKey.decrypt(password: password)
        let privateKey = decrypted.hexString

        // Public key
        let publicKey = keystoreKey.address.eip55String
        
        return (privateKey, publicKey)
        */
        
        // takes less than 0.5 seconds
        let password = "12345678"  // salt
        let mnemonic = Mnemonic.generate(strength: 128)
        let wallet = Wallet(mnemonic: mnemonic, password: password)
        
        // Private key
        let privateKey = wallet.getKey(at: 0).privateKey.hexString
        
        // Public address
        let address = wallet.getKey(at: 0).address.eip55String
        
        return (privateKey, address)
    }
}
