import torch.nn as nn
import sys
sys.path.append('..')
from function.IOConstraint import IOConstraint


class MLP(nn.Module):
    '''
    mnist mlp models.
    default hidden size is 100
    '''

    def __init__(self, io_bits=0, hidden=100):
        super(MLP, self).__init__()
        self.fc1 = nn.Linear(784, hidden)
        self.fc2 = nn.Linear(hidden, 10)
        self.io_bits = io_bits

    def forward(self, x):
        x = x.view(-1, 784)
        out = self.fc1(x)
        out = IOConstraint(io_bits=self.io_bits)(out)
        out = self.fc2(out)
        return out
