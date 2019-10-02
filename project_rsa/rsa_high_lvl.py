#TFE4141 DDS1 Group 6 -  High level implementation

#RSA with Blakley's!

#Mock key information
#public
e_test = 0x10001 
k_e_test = 17 #size

#private
d_test = 0x2cd7623cd3aeb1ce577fc02f1593af0d3c336e60cf6cbd3e95eb1f277ddb43f1 
k_d_test = 256 #size

#Modulus
n_test = 0x6e32c0e025e4f192804eddda592fd99db3ddb9510ef8a2e7ecd0f7e622973171

#Mock message
M_test = 0x4d697474206e61766e206572204361726c205269636861726420537465656e20
k_m=256

def binary_method(M, e, n, k_e):
    # Modular exponentiation function using the RL binary method
    # Calculates the ciphertext C = M^e mod n 
    if e >> (k_e - 1) & 1: # If MSB of e is 1:
        C = M
    else:
        C = 1
    for i in range(k_e - 2, -1, -1): # Move through e bitwise from left to right
        C = (C * C) % n
        if (e >> i) & 1:        # If the current bit is 1
            C = blakley(C,M,n)  # Calculate C = C * M mod n using Blakley's 
                                # algorithm 
    return C

def blakley(a,b,n):
    # Blakley's algorithm for modular multiplication
    R = 0
    for i in range(0,k_m): # Iterating through all bits of a
        R = 2*R + (a >> (k_m-1-i) & 1) * b # Accessing a at the "k_m-1-j"th 
                                           # bit and performs 2*R + a(k_m-1-i)*b

        R = R%n
        if R >= n:
            R = R - n
        if R >= n:
            R = R - n
    return R

#Test run
C_test = binary_method(M_test,e_test,n_test, k_e_test)

print("Original: ", hex(M_test))
print("Encrypted: ", hex(C_test))
print("Decrypted: ", hex(binary_method(C_test,d_test,n_test, k_d_test)))