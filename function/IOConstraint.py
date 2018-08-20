import torch
import torch.nn as nn

class IOConstraint(nn.Module):
    def __init__(self, io_bits):
        '''
        ReLU activation and quantize IO data
        :param io_bits:  Quantified bits of IO
        '''
        super(IOConstraint, self).__init__()
        self.bits = io_bits
        return

    def forward(self, x):
        '''
        first ReLU activation
        second quantize IO data
        :param x: IO data
        :return:  IO data
        '''
        x = x.clamp(min=0)
        if self.bits == 0:
            return x
        _max = torch.max(x.data)
        maximum = float(2 ** self.bits - 1)
        x.data = x.data / _max * maximum
        x.data = torch.round(x.data)
        x.data = x.data / maximum * _max
        return x
