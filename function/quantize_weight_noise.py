import torch
import torch.cuda
import torch.nn as nn
import torch.utils.data

def quantize_weight(_module, quantize_bits, cell, mode='add'):
    '''
    quantize weight
    :param _module:  nn model
    :param quantize_bits:  weight quantize bits
    :param cell:  number of cells
    :param mode:  add/splicing (with different noise)
    :return:
    '''
    if not isinstance(_module, nn.Module):
        print("_module should be nn.Module")
        return
    # save_param :save weight or bias
    # st :standard deviation of noise
    # noise :ratio of st
    max_conductance = 40 # 25k Ohm
    save_param = []
    st = []
    one_cell_bits = int(quantize_bits / cell)

    if mode== 'add':
        noise = 1/(cell**0.5)
    else:
        noise = 1
        sigma = 0
        for i in range(cell):
            sigma += 2 ** (2 * i * one_cell_bits)
        noise *= sigma ** 0.5 / (2 ** (quantize_bits) - 1) * (2 ** one_cell_bits - 1)

    for param in _module.parameters():
        if len(param.size()) > 1:
            _max = torch.max(param.data)
            _min = torch.min(param.data)
            half_span = max(abs(_max), abs(_min))
            param.data /= half_span
            if quantize_bits == 0:
                maximum = 1
            else:
                maximum = (2 ** (quantize_bits - 1) - 1)
            param.data *= maximum
            param.data = torch.round(param.data)
            param.data /= maximum
            save_param.append(param.data)
            st_ = (-0.0006034 * (max_conductance * param.data + 4) ** 2 + 0.06184 * (max_conductance * param.data + 4) + 0.7240) / max_conductance
            st_ *= noise
            st.append(st_)
            param.data *= half_span
    return save_param, st


def noise(_module, st):
    '''
    generate noise with GPU
    :param _module:
    :param st: standard deviation of noise
    :return:
    '''
    counter = 0
    for param in _module.parameters():
        if len(param.size()) > 1:
            _max = torch.max(param.data)
            _min = torch.min(param.data)
            half_span = max(abs(_max), abs(_min))
            param.data = param.data / half_span
            size = param.data.size()
            rand = torch.cuda.FloatTensor(*size).normal_()
            param.data += rand * st[counter]
            param.data *= half_span
            counter += 1


def store_param(_module, params):
    """
    restore the weight
    :param _module: nn
    :param params: weight
    :return:
    """
    counter=0
    for param in _module.parameters():
        if len(param.size()) > 1:
            param.data = params[counter].cuda()
            counter += 1

