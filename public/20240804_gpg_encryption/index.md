# Data Encryption using GPG!


# Securing Your Privacy
The importance of securing your data has become critical in the modern digital era. This post explores a versatile tool called, GnuPG, or GNU Privacy Guard that allows you to encrypt your data and communications, ensuring that only the intended recipients can access them.

## Asymmetric Encryption
Before looking at the GPG, let's first review some encryption approaches. A very naive approach to share encrypted files is to use the same secret key between a sender and a receiver. This approach is known as a symmetric encryption. However, the symmetric approach has a limitation in that it requires a secure method for key exchange. 

To address the issue, asymmetric encryption is preferred. Asymmetric encryption, also known as public-key cryptography, is a method of encryption that uses a pair of keys: a public key and a private key—to encrypt and decrypt data. The *public key* is the key for encryption. It is openly shared and can be distributed to anyone. It allows anyone to encrypt a message intended for the key owner. The *private Key* is the key for decryption. It is kept secret and known only to the owner. It allows the key owner to decrypt messages that were encrypted with the corresponding public key.

This is how asymmetric encryption works:

1. **Key Pair Generation**:
   - A user generates a pair of keys: one public and one private.
   - The public key is shared widely, while the private key is kept secure.

2. **Encryption**:
   - When someone wants to send a secure message, they use the recipient's public key to encrypt the message.
   - This ensures that only the recipient, who has the corresponding private key, can decrypt and read the message.

3. **Decryption**:
   - The recipient uses their private key to decrypt the received message.
   - The private key is the only key that can decrypt the message encrypted with the corresponding public key.

![Example](/images/logo.png)

## How to Use GPG?

- **Installation**:
```sh
sudo apt-get install gnupg # Ubuntu
sudo pacman -S gnupg # Arch
```

- **Generate a GPG Key**:
```sh
gpg --full-gen-key
```

- **Export Public Key**:
  ```sh
  gpg --export --armor your-email@example.com > publickey.asc
  ```

- **Import Public Key**:
  ```sh
  gpg --import publickey.asc
  ```

- **Encrypt a File**:
  ```sh
  gpg --output encryptedfile.gpg --encrypt --recipient recipient@example.com file.txt
  ```

- **Decrypt a File**:
  ```sh
  gpg --output file.txt --decrypt encryptedfile.gpg
  ```



